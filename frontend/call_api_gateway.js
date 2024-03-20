// Select the HTML element to display the visitor count
const visitorCountElement = document.getElementById('visitor-count');

// API Gateway HTTP API endpoint URL
const apiUrl = 'https://v1eanllzwb.execute-api.us-east-1.amazonaws.com/single_lambda_stage';

// Function to *** fetch and update the visitor count ***
function updateVisitorCount() {
  fetch(apiUrl, {
    method: 'GET',
  })
    .then(response => response.json())
    .then(data => {
      // Update the visitor count element with the received updatedCount value
      
      visitorCountElement.textContent = data.updatedCount;
    })
    .catch(error => {
      console.error('Error fetching visitor count:', error);
    });
}

// Call the updateVisitorCount function when the page loads
window.onload = updateVisitorCount;