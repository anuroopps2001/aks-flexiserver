const API_BASE_URL = "/api"; // talks to App Service backend

async function uploadUser() {
    const status = document.getElementById("status");

    status.style.color = "black";
    status.innerText = "Processing...";

    const username = document.getElementById("username").value.trim();
    const email = document.getElementById("email").value.trim();
    const age = parseInt(document.getElementById("age").value);
    const file = document.getElementById("fileInput").files[0];

    // 🔴 basic validation
    if (!username || !email || !age) {
        status.style.color = "red";
        status.innerText = "Fill all fields";
        return;
    }

    if (!file) {
        status.style.color = "red";
        status.innerText = "Select a file";
        return;
    }

    try {
        const formData = new FormData();
        formData.append("name", username);
        formData.append("email", email);
        formData.append("age", age);
        formData.append("file", file);

        const response = await fetch(`${API_BASE_URL}/upload`, {
            method: "POST",
            body: formData
        });

        let result = {};
        try {
            result = await response.json();
        } catch {}

        if (!response.ok) {
            throw new Error(result.error || "Upload failed");
        }

        status.style.color = "green";
        status.innerText = `Success! User ID: ${result.userId}`;

    } catch (err) {
        status.style.color = "red";
        status.innerText = "Error: " + err.message;
    }
}