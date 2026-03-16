package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	_ "github.com/lib/pq"
)

func main() {
	dbHost := os.Getenv("DB_HOST")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	storageAccount := os.Getenv("STORAGE_ACCOUNT_NAME")
	storageKey := os.Getenv("STORAGE_ACCOUNT_KEY")
	containerName := "application-uploads"

	// 1. Database Connection
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s sslmode=require", dbHost, dbUser, dbPass, dbName)
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatal(err)
	}

	// 2. Storage Client
	cred, _ := azblob.NewSharedKeyCredential(storageAccount, storageKey)
	serviceClient, _ := azblob.NewClientWithSharedKeyCredential(fmt.Sprintf("https://%s.blob.core.windows.net/", storageAccount), cred, nil)

	// 3. The Health Check (Using GetProperties on a specific container)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		// Ping DB
		dbErr := db.Ping()

		// Ping Storage via Container Client
		containerClient := serviceClient.ServiceClient().NewContainerClient(containerName)
		_, storageErr := containerClient.GetProperties(context.TODO(), nil)

		if dbErr != nil || storageErr != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprintf(w, "DB: %v, Storage: %v", dbErr, storageErr)
			return
		}
		fmt.Fprintln(w, "Full-Stack Connectivity: OK")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
