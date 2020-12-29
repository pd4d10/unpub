package main

import (
	"archive/tar"
	"compress/gzip"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/ghodss/yaml"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
)

// ResponseWithClientError 4xx
func ResponseWithClientError(c *gin.Context, message string) {
	log.Println("client error:", message)
	c.JSON(http.StatusBadRequest, gin.H{
		"error": gin.H{
			"message": message,
		},
	})
}

// ResponseWithServerError 5xx
func ResponseWithServerError(c *gin.Context, message string) {
	log.Println("server error:", message)
	c.JSON(http.StatusInternalServerError, gin.H{
		"error": gin.H{
			"message": message,
		},
	})
}

// PackageTarballPayload payload
type PackageTarballPayload struct {
	pubspecYaml string
	readme      string
	changelog   string
	pubspec     bson.M
	name        string
	version     string
}

// ReadTarballPayload pacakge.tar.gz
func ReadTarballPayload(r io.Reader) (*PackageTarballPayload, error) {
	gzr, err := gzip.NewReader(r)
	if err != nil {
		return nil, err
	}

	tr := tar.NewReader(gzr)

	var payload PackageTarballPayload

	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		if hdr.Name == "pubspec.yaml" {
			bytes := readBytesFromTar(hdr, tr)
			err := yaml.Unmarshal(bytes, &payload.pubspec)
			if err != nil {
				return nil, err
			}

			var temp struct {
				Name    string `yaml:"name"`
				Version string `yaml:"version"`
			}
			err = yaml.Unmarshal(bytes, &temp)
			if err != nil {
				return nil, err
			}

			payload.name = temp.Name
			payload.version = temp.Version
			payload.pubspecYaml = string(bytes)
		} else if strings.ToLower(hdr.Name) == "readme.md" {
			payload.readme = string(readBytesFromTar(hdr, tr))
		} else if strings.ToLower(hdr.Name) == "changelog.md" {
			payload.changelog = string(readBytesFromTar(hdr, tr))
		}
	}

	return &payload, nil
}
