package main

type User struct {
	ID    uint   `json:"id" gorm:"primarykey"`
	Name  string `json:"name" gorm:"not null"`
	Email string `json:"email" gorm:"unique:not null"`
	Age   int    `json:"age"`
}

type Userparam struct {
	Name  string `json:"name" binding:"required"`
	Email string `json:"email" binding:"required"`
	Age   int    `json:"age"`
}
