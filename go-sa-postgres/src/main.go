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

	http.HandleFunc("/upload-test", func(w http.ResponseWriter, r *http.Request) {
		fileName := "test-file-" + fmt.Sprintf("%d", r.Context().Value("time")) + ".txt"
		content := "This is a test file created by the AKS Full-Stack App!"

		// 1. Upload to Blob Storage
		containerClient := serviceClient.ServiceClient().NewContainerClient("application-uploads")
		blobClient := containerClient.NewBlockBlobClient(fileName)
		_, err := blobClient.UploadBuffer(context.TODO(), []byte(content), nil)
		if err != nil {
			http.Error(w, "Storage Upload Failed: "+err.Error(), 500)
			return
		}

		// 2. Record in PostgreSQL
		query := "INSERT INTO uploads (filename, blob_url) VALUES ($1, $2)"
		_, err = db.Exec(query, fileName, "https://"+storageAccount+".blob.core.windows.net/application-uploads/"+fileName)
		if err != nil {
			http.Error(w, "Database Record Failed: "+err.Error(), 500)
			return
		}

		fmt.Fprintf(w, "Success! File %s uploaded and recorded in DB.", fileName)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
