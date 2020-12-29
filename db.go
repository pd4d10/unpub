package main

import (
	"context"
	"log"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var pc *mongo.Collection
var sc *mongo.Collection

// InitDB db
func InitDB() (*mongo.Collection, *mongo.Collection) {
	client, err := mongo.NewClient(options.Client().ApplyURI(mongodbURI))
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

	pc = client.Database("dart_pub").Collection("packages")
	sc = client.Database("dart_pub").Collection("stats")
	return pc, sc
}
