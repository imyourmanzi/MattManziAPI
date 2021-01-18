// Package logger defines and delivers a custom Logrus logger.
package logger

import (
	"os"

	"github.com/imyourmanzi/MattManziAPI/internal/environment"

	"github.com/sirupsen/logrus"
)

// The shared logger instance, made accessible through this log entry.
var baseLogEntry *logrus.Entry

// New instantiates and sets up the Log.
func New() *logrus.Entry {
	if baseLogEntry != nil {
		baseLogEntry.Debug("New logger requested, but one already exists, returing it")
		return baseLogEntry
	}

	// create a new logger and use json
	log := logrus.New()
	log.SetFormatter(&logrus.JSONFormatter{})

	// set output
	log.SetOutput(os.Stdout)
	log.SetLevel(environment.Verbosity())

	// provide a base entry from which logs can be generated
	baseLogEntry = log.WithFields(logrus.Fields{
		"service":     "mattmanziapi",
		"environment": environment.MMEnvironment(),
	})

	baseLogEntry.WithFields(logrus.Fields{
		"verbosity": log.GetLevel(),
	}).Info("Initialized new logger")

	return baseLogEntry
}
