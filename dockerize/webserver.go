package main

import (
	"bufio"
	"database/sql"
	"dockerize/webserver/articlehandler"
	"dockerize/webserver/kuberneteshandler"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

func init() {
	if _, noLog := os.Stat("/var/logs/webserver/webserver.log"); os.IsNotExist(noLog) {
		newLog, err := os.Create("/var/logs/webserver/webserver.log")
		if err != nil {
			log.Fatal(err)
		}
		newLog.Close()
	}
	dbString := readConfig("server.confi")
	var err error
	db, err := sql.Open("mysql", dbString)
	check(err)
	err = db.Ping()
	check(err)
	dbChecker := time.NewTicker(time.Minute)
	articlehandler.PassDataBase(db)
	kuberneteshandler.PassDataBase(db)
	go checkDB(dbChecker, db) // Check the database connection every minute
}

func main() {
	// Create a new http server
	httpServer := &http.Server{Addr: ":8080", Handler: nil}

	http.Handle("/", http.FileServer(http.Dir("./src")))
	http.HandleFunc("/health", kuberneteshandler.HealthCheck)
	http.HandleFunc("/post-start-hook", kuberneteshandler.PostStartHook)
	http.HandleFunc("/pre-stop-hook", kuberneteshandler.PreStopHookWrapper(httpServer))
	http.HandleFunc("/terminate-gracefully", kuberneteshandler.TerminateGracefully)
	http.HandleFunc("/ready", kuberneteshandler.ReadinessCheck)
	http.HandleFunc("/articles/", articlehandler.ReturnArticle)
	http.HandleFunc("/index.html", articlehandler.ReturnHomePage)
	http.HandleFunc("/api/articles", articlehandler.ReturnArticlesForHomePage)

	// Start the server in a goroutine so that it doesn't block the main thread.
	go func() {
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Could not listen on %s: %v\n", ":8080", err)
		}
	}()

	// Call the PreStopHook function in a goroutine so that it can prepare the shutdown sequence in the background.
	// This goroutine listens to the SIGTERM signal and initiates the graceful shutdown sequence.
	go kuberneteshandler.PreStopHookWrapper(httpServer)

	// Block main to prevent premature exit
	select {}
}

func readConfig(s string) string {
	config, err := os.Open(s)
	check(err)
	defer config.Close()

	scanner := bufio.NewScanner(config)
	scanner.Scan()
	return scanner.Text()
}

func check(err error) {
	if err != nil {
		errorLog, osError := os.OpenFile("/var/logs/webserver/webserver.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if osError != nil {
			log.Fatal(err)
		}
		defer errorLog.Close()
		textLogger := log.New(errorLog, "go-webserver", log.LstdFlags)
		switch err {
		case http.ErrMissingFile:
			log.Print(err)
			textLogger.Fatalln("File missing/cannot be accessed : ", err)
		case sql.ErrTxDone:
			log.Print(err)
			textLogger.Fatalln("SQL connection failure : ", err)
		}
		log.Println("An error has occured : ", err)
	}
}

func checkDB(t *time.Ticker, db *sql.DB) {
	for i := range t.C {
		err := db.Ping()
		if err != nil {
			fmt.Println("Db connection failed at : ", i)
			check(err)
		} else {
			fmt.Println("Db connection successful : ", i)
		}
	}
}
