package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

var baseLogEntry *logrus.Entry

// NewLogger instantiates and sets up the Log.
func NewLogger() *logrus.Entry {
	if baseLogEntry != nil {
		return baseLogEntry
	}

	// create a new logger and use json
	log := logrus.New()
	log.SetFormatter(&logrus.JSONFormatter{})

	// set output
	log.SetOutput(os.Stdout)

	// get the environment we're running in
	env, set := os.LookupEnv("MM_ENVIRONMENT")
	if !set {
		env = "local"
	}

	// provide a base entry from which logs can be generated
	baseLogEntry = log.WithFields(logrus.Fields{
		"service":     "mattmanziapi",
		"environment": env,
	})
	return baseLogEntry
}
