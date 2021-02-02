// Package environment holds information used to interpret the running
// environment.
package environment

import (
	"os"

	"github.com/sirupsen/logrus"
)

// EnvDatabaseURI is the name of the environment variable specifying the API's
// database connection string.
const EnvDatabaseURI = "MM_DATABASE_URI"

// EnvMMEnvironment is the name of the environment variable for the API's
// running environment.
const EnvMMEnvironment = "MM_ENVIRONMENT"

// EnvVerbosity is the name of the environment variable indicating the API's
// verbosity of logging.
const EnvVerbosity = "MM_VERBOSITY"

// DatabaseURI returns the connection string for the API's database, default
// behavior is to connect to localhost.
func DatabaseURI() string {
	uri, set := os.LookupEnv(EnvDatabaseURI)
	if !set {
		uri = "mongodb://localhost:27017/mattmanzi_com?tls=true&tlsCertificateKeyFile=.local/x509/client.pem&tlsCAFile=.local/x509/ca.pem&authMechanism=MONGODB-X509&authSource=%24external&compressors=disabled"
	}

	return uri
}

// MMEnvironment returns the environment we're running in, but defaults to
// "local".
func MMEnvironment() string {
	env, set := os.LookupEnv(EnvMMEnvironment)
	if !set {
		env = "local"
	}

	return env
}

// Verbosity returns the corresponding Logrus Level to the value set in the
// running environment.
func Verbosity() logrus.Level {
	levelString, set := os.LookupEnv(EnvVerbosity)
	if !set {
		return logrus.InfoLevel
	}

	level, err := logrus.ParseLevel(levelString)
	if err != nil {
		return logrus.InfoLevel
	}

	return level
}
