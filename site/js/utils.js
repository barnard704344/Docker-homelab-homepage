/**
 * Shared JavaScript Utilities for Homelab Homepage
 * Contains common functions used across multiple pages
 */

// Escape HTML to prevent XSS
function escapeHtml(text) {
  if (text === null || text === undefined) return '';
  const div = document.createElement('div');
  div.textContent = String(text);
  return div.innerHTML;
}

// Show status message
function showStatus(message, type, duration) {
  const status = document.getElementById('status');
  if (!status) return;
  
  status.textContent = message;
  status.className = `status ${type}`;
  status.style.display = 'block';
  
  const timeout = duration || (type === 'error' ? 5000 : 3000);
  setTimeout(() => {
    status.style.display = 'none';
  }, timeout);
}

// Debounce function
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Format ISO timestamp to localized string
function formatTimestamp(isoString) {
  if (!isoString || typeof isoString !== 'string') {
    return '';
  }

  const parsed = new Date(isoString);
  if (Number.isNaN(parsed.getTime())) {
    return isoString;
  }

  return parsed.toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short'
  });
}

// API helper for consistent fetch calls
async function apiCall(url, options = {}) {
  const defaultOptions = {
    headers: {
      'Content-Type': 'application/json'
    },
    cache: 'no-store'
  };
  
  const mergedOptions = { ...defaultOptions, ...options };
  if (options.headers) {
    mergedOptions.headers = { ...defaultOptions.headers, ...options.headers };
  }
  
  try {
    const response = await fetch(url, mergedOptions);
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
      throw new Error(errorData.error || `HTTP ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error(`API call to ${url} failed:`, error);
    throw error;
  }
}

// GET request helper
async function apiGet(url) {
  return apiCall(url, { method: 'GET' });
}

// POST request helper
async function apiPost(url, data) {
  return apiCall(url, {
    method: 'POST',
    body: JSON.stringify(data)
  });
}

// Load JSON from server with error handling
async function loadJsonFromServer(endpoint, defaultValue = null) {
  try {
    const data = await apiGet(endpoint);
    return data;
  } catch (error) {
    console.log(`Could not load from ${endpoint}:`, error.message);
    return defaultValue;
  }
}

// Save JSON to server with error handling  
async function saveJsonToServer(endpoint, data) {
  try {
    const result = await apiPost(endpoint, data);
    return { success: true, data: result };
  } catch (error) {
    console.error(`Could not save to ${endpoint}:`, error.message);
    return { success: false, error: error.message };
  }
}

// Get favicon URL from Google's service
function getFaviconUrl(url) {
  try {
    const domain = new URL(url).hostname;
    return `https://www.google.com/s2/favicons?domain=${domain}&sz=16`;
  } catch {
    return '';
  }
}

// Export utilities for use in modules (if using ES6 modules)
if (typeof window !== 'undefined') {
  window.homelabUtils = {
    escapeHtml,
    showStatus,
    debounce,
    formatTimestamp,
    apiCall,
    apiGet,
    apiPost,
    loadJsonFromServer,
    saveJsonToServer,
    getFaviconUrl
  };
}
