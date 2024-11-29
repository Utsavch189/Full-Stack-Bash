const form = document.getElementById("itemForm");
const itemId = document.getElementById("itemId");
const itemName = document.getElementById("itemName");
const itemDescription = document.getElementById("itemDescription");
const itemsList = document.getElementById("itemsList");

// Fetch and display items
function fetchItems() {
    fetch("/cgi-bin/backend.sh?action=read")
        .then(response => response.json())
        .then(data => {
	    console.log(data);
            itemsList.innerHTML = "";
            data.forEach(item => {
                const li = document.createElement("li");
                li.innerHTML = `
                    <span>${item.name}: ${item.description}</span>
                    <button onclick="editItem(${item.id}, '${item.name}', '${item.description}')">Edit</button>
                    <button onclick="deleteItem(${item.id})">Delete</button>
                `;
                itemsList.appendChild(li);
            });
        });
}

// Add or update item
form.addEventListener("submit", event => {
    event.preventDefault();
 
    const name = document.getElementById('itemName').value;
    const description = document.getElementById('itemDescription').value;
    const action = itemId.value ? "update" : "create";
    const url= action==='create' ? `/cgi-bin/backend.sh?action=${action}` : `/cgi-bin/backend.sh?action=${action}&id=${itemId.value}`
    // Set up fetch request
    fetch(url, {
        method: "POST",
	headers:{
	  "Content-Type" : "application/json",
	  "Content-Length": JSON.stringify({ name, description }).length.toString()
	},
        body: JSON.stringify({name:name,description:description})
    })
    .then(response => {
        return response.json();
    })
    .then((data) => {
	console.log(data);
        fetchItems();  // Refresh the item list after submit
        form.reset();  // Clear form fields
    })
    .catch(error => {
        console.error("Error:", error);
    });
});

// Edit item
function editItem(id, name, description) {
    itemId.value = id;
    itemName.value = name;
    itemDescription.value = description;
}

// Delete item
function deleteItem(id) {
    fetch(`/cgi-bin/backend.sh?action=delete&id=${id}`)
        .then(() => fetchItems());
}

fetchItems();

