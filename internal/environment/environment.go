// Package environment holds information used to interpret the running
// environment.
package environment

import "os"

// EnvMMEnvironment is the name of the environment variable for the API's
// running environment.
const EnvMMEnvironment = "MM_ENVIRONMENT"

// MMEnvironment returns the environment we're running in, but defaults to
// "local".
func MMEnvironment() string {
	env, set := os.LookupEnv(EnvMMEnvironment)
	if !set {
		env = "local"
	}

	return env
}
