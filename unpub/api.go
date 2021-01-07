package unpub

import (
	"context"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
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

	// get uploader email via googleapis
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

	tp, err := ReadTarballPayload(file, email)
	if err != nil {
		ResponseWithServerError(c, err.Error())
		return
	}

	// check if pubspec is valid
	if tp.Name == "" || tp.Version == "" {
		ResponseWithClientError(c, "Invalid pubspec.yaml")
		return
	}

	// check if package exists
	p := metaStore.QueryPackage(tp.Name)
	if p != nil {
		// check if email in uploaders
		isUploader := false
		for _, uploader := range p.Uploaders {
			if email == uploader {
				isUploader = true
				break
			}
		}
		if !isUploader {
			ResponseWithClientError(c, email+" is not an uploader of "+tp.Name)
			return
		}

		// check duplicated version
		for _, v := range p.Versions {
			if tp.Version == v.Version {
				ResponseWithClientError(c, "Version invalid: "+tp.Name+"@"+tp.Version+" already exists.")
				return
			}
		}
	}

	// upload tarball
	bytes, err := ioutil.ReadAll(file)
	if err != nil {
		ResponseWithServerError(c, err.Error())
		return
	}
	tarballStore.Upload(tp.Name, tp.Version, bytes)

	// update meta info
	metaStore.AddVersion(*tp)

	c.Redirect(http.StatusFound, scheme+c.Request.Host+"/api/packages/versions/newUploadFinish")
}

// PackagesFallback PackagesFallback
func PackagesFallback(c *gin.Context) {
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

	p := metaStore.QueryPackage(name)
	if p == nil {
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
