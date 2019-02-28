package main

import (
	"flag"
	"fmt"
	"os"
	"testing"

	"github.com/DATA-DOG/godog"
	"github.com/DATA-DOG/godog/colors"
)

var (
	opt = godog.Options{
		Output:    colors.Colored(os.Stdout),
		Format:    "pretty",
		Randomize: -1,
	}

	goDogGoT *testing.T
)

func init() {
	godog.BindFlags("godog.", flag.CommandLine, &opt)
}

func TestMain(m *testing.M) {
	flag.Parse()
	opt.Paths = flag.Args()
	os.Exit(m.Run())
}

func TestGoDogGo(t *testing.T) {
	goDogGoT = t
	t.Helper() // this function

	fmt.Print("\nFirst Tests: ")
	t.Run("First=1", func(t *testing.T) { OrderedTest(true, t) })
	fmt.Print("Remaining Tests: ")
	t.Run("Remaining=1", func(t *testing.T) { OrderedTest(false, t) })
}

func OrderedTest(first bool, t *testing.T) {
	opt.Tags = "~@First"
	if first {
		opt.Tags = "@First"
	}
	goDogGoT = t
	status := godog.RunWithOptions("godogs", func(s *godog.Suite) {
		GacFeatureContext(s)
		WorkspaceFeatureContext(s)
	}, opt)
	if status > 0 {
		t.FailNow()
	}
}
