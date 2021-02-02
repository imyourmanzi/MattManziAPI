// Package database defines and delivers a connection to a MongoDB instance.
package database

import (
	"context"
	"time"

	"github.com/imyourmanzi/MattManziAPI/internal/environment"
	"github.com/imyourmanzi/MattManziAPI/internal/logger"
	"github.com/imyourmanzi/MattManziAPI/internal/logic"
	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

var log = logger.New().WithField("package", "database")

// The shared MongoDB connection pool.
var client *mongo.Client

// The shared function to close the MongoDB client.
var close func()

// NewClient creates a new MongoDB client (a conncetion pool).
func NewClient() (*mongo.Client, func()) {

	// check if something is missing
	if !logic.AreAllSame(client != nil, close != nil) {
		log.WithFields(logrus.Fields{
			"isClientNil":    client == nil,
			"isCloseFuncNil": close == nil,
		}).Fatal("New database client requested, but connection set is incomplete")
	}

	// return existing connection set
	if client != nil && close != nil {
		log.Debug("New database client requested, but one already exists, returing it")
		return client, close
	}

	// get the connection string
	uri := environment.DatabaseURI()
	log.WithFields(logrus.Fields{
		"uri": uri,
	}).Debug("Retrieved connection URI")

	// parse uri string into client options
	opts := options.Client().ApplyURI(uri)
	log.WithFields(logrus.Fields{
		"auth":            opts.Auth,
		"hosts":           opts.Hosts,
		"numCertificates": len(opts.TLSConfig.Certificates),
		"uri":             opts.GetURI(),
	}).Debug("Parsed URI string")

	// create and store a new client
	cl, err := mongo.NewClient(opts)
	if err != nil {
		log.Fatal(err)
	}
	client = cl
	log.Debug("Created new client")

	// create a database context to use
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// connect the client
	err = client.Connect(ctx)
	if err != nil {
		log.Fatal(err)
	}
	log.Debug("Successfully connected to the database")

	// close function will disconnect and kill the context
	close = func() {
		err = client.Disconnect(context.Background())
		if err != nil {
			log.Fatal(err)
		}
		log.Debug("Closed database connection")
	}

	// debugging santiy check to ping the database before handing off the client
	err = client.Ping(ctx, readpref.Primary())
	if err != nil {
		log.Fatal(err)
	}
	log.Debug("Successfully pinged the database")

	log.Info("Initialized new database client")
	return client, close
}
