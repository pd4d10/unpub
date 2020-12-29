package main

import (
	"archive/tar"
	"context"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"golang.org/x/oauth2"
	goauth2 "google.golang.org/api/oauth2/v1"
	goption "google.golang.org/api/option"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// PubPackage package
type PubPackage struct {
	Name      string              `json:"name"`
	Private   bool                `json:"private"`
	Uploaders []string            `json:"uploaders"`
	Versions  []PubPackageVersion `json:"versions"`
	Download  int                 `json:"download"`
	CreatedAt time.Time           `json:"createdAt"`
	UpdatedAt time.Time           `json:"updatedAt"`
}

// PubPackageVersion package version
type PubPackageVersion struct {
	Version     string    `bson:"version"`
	Pubspec     bson.M    `bson:"pubspec"`
	PubspecYaml string    `bson:"pubspecYaml"`
	Readme      string    `bson:"readme"`
	Changelog   string    `bson:"changelog"`
	CreatedAt   time.Time `bson:"createdAt"`
}

func main() {

	timeout := 3 * time.Second
	upstream := "https://pub.dev"

	client, err := mongo.NewClient(options.Client().ApplyURI("mongodb://127.0.0.1:27017"))
	if err != nil {
		log.Fatal(err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	err = client.Connect(ctx)
	if err != nil {
		log.Fatal(err)
	}
	defer func() {
		if err = client.Disconnect(ctx); err != nil {
			panic(err)
		}
	}()

	packages := client.Database("dart_pub").Collection("packages")
	// stats := client.Database("dart_pub").Collection("stats")

	router := gin.Default()

	router.POST("/api/packages/versions/newUpload", func(c *gin.Context) {
		auth := c.GetHeader("Authorization")
		token := strings.TrimPrefix(auth, "Bearer ")
		if token == "" {
			ResponseWithClientError(c, "Authentication is required, please add `authorization` header.")
			return
		}

		// get email via googleapis
		ctx, cancel = context.WithTimeout(context.Background(), timeout)
		defer cancel()
		ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
		service, err := goauth2.NewService(ctx, goption.WithTokenSource(ts))
		if err != nil {
			ResponseWithServerError(c, err.Error())
			return
		}

		ti, err := service.Tokeninfo().Do()
		if err != nil {
			ResponseWithServerError(c, err.Error())
			return
		}
		email := ti.Email

		// read package.tar.gz
		fh, err := c.FormFile("file")
		if err != nil {
			ResponseWithServerError(c, err.Error())
			return
		}

		file, err := fh.Open()
		if err != nil {
			ResponseWithServerError(c, err.Error())
			return
		}
		defer file.Close()

		tp, err := ReadTarballPayload(file)
		if err != nil {
			ResponseWithServerError(c, err.Error())
			return
		}

		// check
		if tp.pubspecYaml == "" {
			ResponseWithClientError(c, err.Error())
			return
		}

		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()
		filter := bson.M{"name": tp.name}
		var p PubPackage
		err = packages.FindOne(ctx, filter).Decode(&p)
		if err != nil {
			if strings.Contains(err.Error(), "no documents") {
				// no documents, go ahead
			} else {
				ResponseWithServerError(c, err.Error())
				return
			}
		} else {
			// check if email in uploaders
			isUploader := false
			for _, uploader := range p.Uploaders {
				if email == uploader {
					isUploader = true
					break
				}
			}
			if !isUploader {
				ResponseWithClientError(c, email+" is not an uploader of "+tp.name)
				return
			}

			// check duplicated version
			for _, v := range p.Versions {
				if tp.version == v.Version {
					ResponseWithClientError(c, "Version invalid: "+tp.name+"@"+tp.version+" already exists.")
					return
				}
			}
		}

		// upload tarball

		// update meta info
		ctx, cancel = context.WithTimeout(context.Background(), timeout)
		defer cancel()
		now := time.Now()
		filter = bson.M{"name": tp.name}
		update := bson.M{
			"$push": bson.M{
				"versions": PubPackageVersion{
					Version:     tp.version,
					Pubspec:     tp.pubspec,
					PubspecYaml: tp.pubspecYaml,
					Readme:      tp.readme,
					Changelog:   tp.changelog,
					CreatedAt:   now,
				},
			},
			"$addToSet": bson.M{
				"uploaders": email,
			},
			"$setOnInsert": bson.M{
				"createdAt": now,
				"private":   true,
				"download":  0,
			},
			"$set": bson.M{
				"updatedAt": now,
			},
		}
		opts := options.Update().SetUpsert(true)
		packages.UpdateOne(ctx, filter, update, opts)
		c.Redirect(http.StatusFound, "http://"+c.Request.Host+"/api/packages/versions/newUploadFinish")
	})

	router.GET("/api/packages/*action", func(c *gin.Context) {
		action := c.Param("action")

		if action == "/versions/new" {
			c.JSON(http.StatusOK, gin.H{
				"url":    "http://" + c.Request.Host + "/api/packages/versions/newUpload",
				"fields": gin.H{},
			})
			return
		} else if action == "/versions/newUploadFinish" {
			err := c.Param("error")
			if err != "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": gin.H{
						"message": err,
					},
				})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"success": gin.H{
					"message": "Successfully uploaded package.",
				},
			})
			return
		}

		name := strings.TrimLeft(action, "/")
		var p PubPackage

		ctx, cancel := context.WithTimeout(context.Background(), timeout)
		defer cancel()
		filter := bson.M{"name": name}
		err := packages.FindOne(ctx, filter).Decode(&p)
		if err != nil {
			c.Redirect(http.StatusFound, upstream+c.Request.URL.Path)
			return
		}

		var versions []interface{}
		for _, v := range p.Versions {
			versions = append(versions, gin.H{
				"version":     v.Version,
				"pubspec":     v.Pubspec,
				"archive_url": "http://" + c.Request.Host + "/packages/" + name + "/versions/" + v.Version + ".tar.gz",
				"published":   v.CreatedAt,
			})
		}

		c.JSON(http.StatusOK, gin.H{
			"name":     p.Name,
			"latest":   versions[len(versions)-1], // TODO:
			"versions": versions,
		})
	})

	router.Run()
}

func readBytesFromTar(hdr *tar.Header, tr *tar.Reader) []byte {
	fi := hdr.FileInfo()
	b := make([]byte, fi.Size())
	io.ReadFull(tr, b)
	return b
}
