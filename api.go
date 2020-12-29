package main

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/oauth2"
	goauth2 "google.golang.org/api/oauth2/v1"
	goption "google.golang.org/api/option"
)

// PackagesNewUpload PackagesNewUpload
func PackagesNewUpload(c *gin.Context) {
	auth := c.GetHeader("Authorization")
	token := strings.TrimPrefix(auth, "Bearer ")
	if token == "" {
		ResponseWithClientError(c, "Authentication is required, please add `authorization` header.")
		return
	}

	// get email via googleapis
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
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

	// check if pubspec is valid
	if tp.name == "" || tp.version == "" {
		ResponseWithClientError(c, "Invalid pubspec.yaml")
		return
	}

	// check if package exists
	ctx, cancel = context.WithTimeout(context.Background(), timeout)
	defer cancel()
	filter := bson.M{"name": tp.name}
	var p PubPackage
	err = pc.FindOne(ctx, filter).Decode(&p)
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
	pc.UpdateOne(ctx, filter, update, opts)
	c.Redirect(http.StatusFound, scheme+c.Request.Host+"/api/packages/versions/newUploadFinish")
}

// PackageFallback PackageFallback
func PackageFallback(c *gin.Context) {
	action := c.Param("action")

	if action == "/versions/new" {
		c.JSON(http.StatusOK, gin.H{
			"url":    scheme + c.Request.Host + "/api/packages/versions/newUpload",
			"fields": gin.H{},
		})
		return
	} else if action == "/versions/newUploadFinish" {
		err := c.Param("error")
		if err != "" {
			ResponseWithClientError(c, err)
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
	err := pc.FindOne(ctx, filter).Decode(&p)
	if err != nil {
		c.Redirect(http.StatusFound, upstream+c.Request.URL.Path)
		return
	}

	var versions []interface{}
	for _, v := range p.Versions {
		versions = append(versions, gin.H{
			"version":     v.Version,
			"pubspec":     v.Pubspec,
			"archive_url": scheme + c.Request.Host + "/packages/" + name + "/versions/" + v.Version + ".tar.gz",
			"published":   v.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"name":     p.Name,
		"latest":   versions[len(versions)-1], // TODO:
		"versions": versions,
	})
}
