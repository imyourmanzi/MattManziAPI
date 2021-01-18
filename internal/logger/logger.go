package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

var baseLogEntry *logrus.Entry

// NewLogger instantiates and sets up the Log.
func NewLogger(pkg string) *logrus.Entry {
	if baseLogEntry != nil {
		return baseLogEntry
	}

	// create a new logger and use json
	log := logrus.New()
	log.SetFormatter(&logrus.JSONFormatter{})

	// set output
	log.SetOutput(os.Stdout)

	// provide a base entry from which logs can be generated
	baseLogEntry = log.WithField("service", "mattmanziapi")
	return baseLogEntry
}
