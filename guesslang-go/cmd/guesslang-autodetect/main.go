package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"github.com/robherley/guesslang-go/pkg/guesser"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <filename>\n", os.Args[0])
		os.Exit(1)
	}

	filename := os.Args[1]

	// Read the file content
	content, err := ioutil.ReadFile(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading file: %v\n", err)
		os.Exit(1)
	}

	// Initialize guesslang guesser
	gsr, err := guesser.New()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing guesser: %v\n", err)
		os.Exit(1)
	}

	// Guess the language from the content
	answer, err := gsr.Guess(string(content))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error detecting language: %v\n", err)
		os.Exit(1)
	}

	// Output the result based on reliability and confidence
	if len(answer.Predictions) > 0 {
		// If the result is reliable, use it
		if answer.Reliable {
			fmt.Println(answer.Predictions[0].Language)
		} else {
			// If not reliable but confidence is reasonable, still use it
			if answer.Predictions[0].Confidence > 0.1 {
				fmt.Println(answer.Predictions[0].Language)
			} else {
				fmt.Println("unknown")
			}
		}
	} else {
		fmt.Println("unknown")
	}
}
