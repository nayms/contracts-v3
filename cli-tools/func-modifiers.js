const fs = require("fs");
const path = require("path");
const baseDirectory = path.join(__dirname, "..", "forge-artifacts");

// Directory paths from which you want to get the filenames
const directoriesToCheck = [path.join(__dirname, "..", "src", "diamonds", "nayms", "facets"), path.join(__dirname, "..", "src", "diamonds", "shared", "facets")];

// Function to get the filenames from the given directories
function getFilenamesFromDirectories(directories) {
    let filenames = [];

    for (let directory of directories) {
        const files = fs.readdirSync(directory);

        for (let file of files) {
            const filename = path.parse(file).name; // get the name of the file without extension
            filenames.push(filename);
        }
    }

    return filenames;
}

// Function to get the function name and modifiers from AST
function getModifiersFromAST(ast, filter) {
    const functions = [];

    function traverse(node) {
        if (node.nodeType === "FunctionDefinition") {
            const funcName = node.name;
            const modifiers = node.modifiers.map((modifier) => modifier.modifierName.name);

            // Only add functions that have modifiers if the filter flag is set
            if (filter ? modifiers.length > 0 : true) {
                functions.push({ funcName, modifiers });
            }
        }

        for (let key in node) {
            if (node[key] !== null && typeof node[key] === "object") {
                traverse(node[key]);
            }
        }
    }

    traverse(ast);
    return functions;
}

// Get filenames from the specified directories
const filenamesToLookFor = getFilenamesFromDirectories(directoriesToCheck);

// Check for --filter argument
const filter = process.argv.includes("--filter");

// Loop through the filenames
filenamesToLookFor.forEach((filename) => {
    const filePath = path.join(baseDirectory, filename + ".sol", filename + ".json");

    // Check if file exists in the main directory
    if (fs.existsSync(filePath)) {
        fs.readFile(filePath, "utf8", (err, data) => {
            if (err) {
                console.error(`Error reading file from disk: ${err}`);
            } else {
                // Parse the JSON
                const json = JSON.parse(data);

                // Get the function name and modifiers
                const functions = getModifiersFromAST(json, filter);

                // Log the function name and modifiers
                functions.forEach(({ funcName, modifiers }) => {
                    console.log(`Function: ${funcName}, Modifiers: ${modifiers.join(", ")}`);
                });
            }
        });
    }
});
