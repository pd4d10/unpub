package main

import (
	"log"
	"os"
	"path"

	"github.com/bytedance/unpub/unpub"
)

const (
	mongodbURI = "mongodb://127.0.0.1:27017"
)

func main() {
	metaStore := unpub.MongoStore{}
	metaStore.Init(mongodbURI)

	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	tarballStore := unpub.FileStore{}
	tarballStore.Init(path.Join(cwd, "unpub-packages"))

	router := unpub.SetupRouter(metaStore, tarballStore)
	router.Run()
}
