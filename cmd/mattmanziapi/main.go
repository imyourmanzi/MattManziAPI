// The MattManzi.com RESTful API.
package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/imyourmanzi/MattManziAPI/internal/database"
	"github.com/imyourmanzi/MattManziAPI/internal/logger"
	"github.com/imyourmanzi/MattManziAPI/internal/router"
)

var log = logger.New()

func main() {
	// setup database
	_, close := database.NewClient()
	defer close()
	log.Debug("Initialized database client")

	r := router.New()

	r.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"version": "0.1.0"})
	})

	log.Println("Starting router engine")
	r.Run("localhost:8080")
}
