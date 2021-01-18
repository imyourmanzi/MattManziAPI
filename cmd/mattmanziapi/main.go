// The MattManzi.com RESTful API.
package main

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/imyourmanzi/MattManziAPI/internal/logger"
	"github.com/imyourmanzi/MattManziAPI/internal/router"
)

var log = logger.New()

func main() {
	r := router.New()

	r.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"version": "0.1.0"})
	})

	r.Run("localhost:8080")
	log.Println("Started router engine, API is ready")
}
