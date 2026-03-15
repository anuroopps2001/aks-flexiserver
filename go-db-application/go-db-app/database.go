package main

import (
	"fmt"
	"log"
	"os"
	"strconv"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type DBClient interface {
	Ready() bool
	RunMigration() error
}

type Client struct {
	db *gorm.DB
}

func (c Client) Ready() bool {
	var ready int
	err := c.db.Raw("SELECT 1").Row().Scan(&ready)
	return err == nil && ready == 1
}

func (c Client) RunMigration() error {
	if !c.Ready() {
		return fmt.Errorf("database is not ready")
	}
	err := c.db.AutoMigrate(&User{})
	if err != nil {
		return err
	}

	return nil
}

func NewDBClient() (Client, error) {
	dbHost := os.Getenv("DB_HOST")
	dbUsername := os.Getenv("DB_USERNAME")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbPort := os.Getenv("DB_PORT")

	// ---- VALIDATION (CRITICAL) ----
	if dbHost == "" || dbUsername == "" || dbPassword == "" || dbName == "" || dbPort == "" {
		return Client{}, fmt.Errorf("one or more required DB environment variables are missing")
	}

	databasePort, err := strconv.Atoi(dbPort)
	if err != nil {
		log.Fatal("Invalid DB_PORT")
	}

	log.Printf(
		"DB CONFIG -> host=%s user=%s db=%s port=%d",
		dbHost, dbUsername, dbName, databasePort,
	)

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%d sslmode=disable",
		dbHost, dbUsername, dbPassword, dbName, databasePort,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return Client{}, err
	}

	client := Client{db}
	return client, nil
}
