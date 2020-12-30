package unpub

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var pc *mongo.Collection
var sc *mongo.Collection

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

// MongoStore MongoStore
type MongoStore struct {
}

// Init Init
func (MongoStore) Init(uri string) (*mongo.Collection, *mongo.Collection) {
	client, err := mongo.NewClient(options.Client().ApplyURI(uri))
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

// QueryPackage QueryPackage
func (MongoStore) QueryPackage(name string) *PubPackage {
	var p PubPackage

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	filter := bson.M{"name": name}
	err := pc.FindOne(ctx, filter).Decode(&p)
	if err != nil {
		return nil
	}
	return &p
}

// AddVersion AddVersion
func (MongoStore) AddVersion(tp VersionPayload) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	now := time.Now()
	filter := bson.M{"name": tp.Name}
	update := bson.M{
		"$push": bson.M{
			"versions": PubPackageVersion{
				Version:     tp.Version,
				Pubspec:     tp.Pubspec,
				PubspecYaml: tp.PubspecYaml,
				Readme:      tp.Readme,
				Changelog:   tp.Changelog,
				CreatedAt:   now,
			},
		},
		"$addToSet": bson.M{
			"uploaders": tp.Uploader,
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
	_, err := pc.UpdateOne(ctx, filter, update, opts)
	return err
}
