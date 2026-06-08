package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

const registryURL = "https://raw.githubusercontent.com/coolguy565/awpm/refs/heads/main/pkgregistry.json"

type Registry struct {
	Version  string             `json:"version"`
	Packages map[string]Package `json:"packages"`
}

type Package struct {
	Latest          string       `json:"latest"`
	Description     string       `json:"description"`
	Script          string       `json:"script"`
	SHA256          string       `json:"sha256"`
	Tier            int          `json:"tier"`
	AllowUnverified bool         `json:"allow_unverified"`
	UpdateChannel   string       `json:"update_channel"`
	Dependencies    Dependencies `json:"dependencies"`
}

type Dependencies struct {
	System []string   `json:"system"`
	AnyOf  [][]string `json:"any_of"`
}

// ---------------- ENV ----------------

func insecureEnabled() bool {
	return strings.ToLower(os.Getenv("AWPM_INSECURE_FETCH")) == "true"
}

// ---------------- HTTP CLIENT (FIXED TLS) ----------------

func httpClient() *http.Client {
	if insecureEnabled() {
		fmt.Println("WARNING: AWPM_INSECURE_FETCH=true (TLS verification disabled)")
	}

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: insecureEnabled(),
		},
	}

	return &http.Client{
		Transport: tr,
	}
}

// ---------------- MAIN ----------------

func main() {
	if len(os.Args) < 2 {
		fmt.Println("AWPM - Awesome Package Manager")
		fmt.Println("Usage:")
		fmt.Println("  awpm install <pkg> [--noconfirm]")
		fmt.Println("  awpm list")
		fmt.Println("  awpm search <query>")
		return
	}

	command := os.Args[1]

	noconfirm := false
	for _, a := range os.Args {
		if a == "--noconfirm" {
			noconfirm = true
		}
	}

	switch command {

	case "install":
		if len(os.Args) < 3 {
			fmt.Println("Usage: awpm install <package>")
			return
		}

		name := os.Args[2]

		if err := install(name, noconfirm); err != nil {
			fmt.Println("Error:", err)
		}

	case "list":
		if err := listPackages(); err != nil {
			fmt.Println("Error:", err)
		}

	case "search":
		if len(os.Args) < 3 {
			fmt.Println("Usage: awpm search <query>")
			return
		}

		query := strings.ToLower(os.Args[2])
		if err := searchPackages(query); err != nil {
			fmt.Println("Error:", err)
		}

	default:
		fmt.Println("Unknown command:", command)
	}
}

// ---------------- REGISTRY ----------------

func loadRegistry() (*Registry, error) {
	client := httpClient()

	resp, err := client.Get(registryURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var registry Registry
	if err := json.Unmarshal(body, &registry); err != nil {
		return nil, err
	}

	return &registry, nil
}

// ---------------- INSTALL ----------------

func install(name string, noconfirm bool) error {
	registry, err := loadRegistry()
	if err != nil {
		return err
	}

	pkg, ok := registry.Packages[name]
	if !ok {
		return fmt.Errorf("package not found: %s", name)
	}

	fmt.Println("================================")
	fmt.Println("Installing:", name)
	fmt.Println("Description:", pkg.Description)
	fmt.Println("================================")

	if err := checkDeps(pkg); err != nil {
		return err
	}

	if pkg.Tier == 3 {
		fmt.Println("\nWARNING: Tier 3 package (remote script execution)")
	}

	if !noconfirm {
		fmt.Print("\nContinue installation? (y/N): ")

		var input string
		fmt.Scanln(&input)

		if input != "y" && input != "Y" {
			fmt.Println("Aborted.")
			return nil
		}
	}

	fmt.Println("\nDownloading install script...")

	client := httpClient()

	resp, err := client.Get(pkg.Script)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	script, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	tmpFile := "/tmp/awpm-install.sh"
	if err := os.WriteFile(tmpFile, script, 0755); err != nil {
		return err
	}

	fmt.Println("Running installer script...")

	cmd := exec.Command("sh", tmpFile)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

// ---------------- LIST ----------------

func listPackages() error {
	registry, err := loadRegistry()
	if err != nil {
		return err
	}

	fmt.Println("Available packages:")
	fmt.Println("-------------------")

	for name, pkg := range registry.Packages {
		fmt.Printf("- %s (%s)\n  %s\n\n", name, pkg.Latest, pkg.Description)
	}

	return nil
}

// ---------------- SEARCH ----------------

func searchPackages(query string) error {
	registry, err := loadRegistry()
	if err != nil {
		return err
	}

	fmt.Println("Search results for:", query)
	fmt.Println("-------------------")

	found := false

	for name, pkg := range registry.Packages {
		if strings.Contains(strings.ToLower(name), query) ||
			strings.Contains(strings.ToLower(pkg.Description), query) {

			fmt.Printf("- %s (%s)\n  %s\n\n", name, pkg.Latest, pkg.Description)
			found = true
		}
	}

	if !found {
		fmt.Println("No packages found.")
	}

	return nil
}

// ---------------- DEPENDENCIES ----------------

func checkDeps(pkg Package) error {
	for _, dep := range pkg.Dependencies.System {
		if !commandExists(dep) {
			return fmt.Errorf("missing required dependency: %s", dep)
		}
	}

	for _, group := range pkg.Dependencies.AnyOf {
		ok := false
		for _, dep := range group {
			if commandExists(dep) {
				ok = true
				break
			}
		}
		if !ok {
			return fmt.Errorf("missing required dependency (need one of): %v", group)
		}
	}

	return nil
}

func commandExists(cmd string) bool {
	_, err := exec.LookPath(cmd)
	return err == nil
}
