package main

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
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

const (
	timeout    = 3 * time.Second
	upstream   = "https://pub.dev"
	scheme     = "http://"
	mongodbURI = "mongodb://127.0.0.1:27017"
)

func setupRouter() *gin.Engine {
	router := gin.Default()
	router.POST("/api/packages/versions/newUpload", PackagesNewUpload)
	router.GET("/api/packages/*action", PackageFallback)
	return router
}

func main() {
	InitDB()
	router := setupRouter()
	router.Run()
}
