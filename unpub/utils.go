package unpub

import (
	"archive/tar"
	"compress/gzip"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/ghodss/yaml"
	"github.com/gin-gonic/gin"
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

// ReadTarballPayload pacakge.tar.gz
func ReadTarballPayload(r io.Reader, uploader string) (*VersionPayload, error) {
	gzr, err := gzip.NewReader(r)
	if err != nil {
		return nil, err
	}

	tr := tar.NewReader(gzr)

	payload := VersionPayload{Uploader: uploader}

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
			err := yaml.Unmarshal(bytes, &payload.Pubspec)
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

			payload.Name = temp.Name
			payload.Version = temp.Version
			payload.PubspecYaml = string(bytes)
		} else if strings.ToLower(hdr.Name) == "readme.md" {
			payload.Readme = string(readBytesFromTar(hdr, tr))
		} else if strings.ToLower(hdr.Name) == "changelog.md" {
			payload.Changelog = string(readBytesFromTar(hdr, tr))
		}
	}

	return &payload, nil
}

func readBytesFromTar(hdr *tar.Header, tr *tar.Reader) []byte {
	fi := hdr.FileInfo()
	b := make([]byte, fi.Size())
	io.ReadFull(tr, b)
	return b
}
