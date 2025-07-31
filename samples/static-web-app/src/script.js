// Smooth scrolling for navigation
function scrollToSection(sectionId) {
    const element = document.getElementById(sectionId);
    if (element) {
        element.scrollIntoView({ 
            behavior: 'smooth',
            block: 'start'
        });
    }
}

// Navigation active state
document.addEventListener('DOMContentLoaded', function() {
    // Measure page load time
    const loadTime = performance.now();
    const loadTimeElement = document.getElementById('loadTime');
    if (loadTimeElement) {
        loadTimeElement.textContent = Math.round(loadTime) + 'ms';
    }
    
    // Update clocks
    updateClocks();
    setInterval(updateClocks, 1000);
    
    // Initialize color generator
    generateRandomColor();
    
    // Navigation scroll spy
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    
    window.addEventListener('scroll', () => {
        let current = '';
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (scrollY >= (sectionTop - 200)) {
                current = section.getAttribute('id');
            }
        });
        
        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href').substring(1) === current) {
                link.classList.add('active');
            }
        });
    });
});

// Calculator functionality
function calculate() {
    const num1 = parseFloat(document.getElementById('num1').value);
    const num2 = parseFloat(document.getElementById('num2').value);
    const operation = document.getElementById('operation').value;
    const resultDiv = document.getElementById('result');
    
    if (isNaN(num1) || isNaN(num2)) {
        resultDiv.innerHTML = '<span style="color: var(--danger-color);">Please enter valid numbers</span>';
        return;
    }
    
    let result;
    let operationSymbol;
    
    switch(operation) {
        case 'add':
            result = num1 + num2;
            operationSymbol = '+';
            break;
        case 'subtract':
            result = num1 - num2;
            operationSymbol = '-';
            break;
        case 'multiply':
            result = num1 * num2;
            operationSymbol = '×';
            break;
        case 'divide':
            if (num2 === 0) {
                resultDiv.innerHTML = '<span style="color: var(--danger-color);">Cannot divide by zero!</span>';
                return;
            }
            result = num1 / num2;
            operationSymbol = '÷';
            break;
        default:
            resultDiv.innerHTML = '<span style="color: var(--danger-color);">Invalid operation</span>';
            return;
    }
    
    resultDiv.innerHTML = `
        <div style="color: var(--success-color);">
            ${num1} ${operationSymbol} ${num2} = <strong>${result.toFixed(2)}</strong>
        </div>
    `;
}

// Color generator functionality
function generateRandomColor() {
    const r = Math.floor(Math.random() * 256);
    const g = Math.floor(Math.random() * 256);
    const b = Math.floor(Math.random() * 256);
    
    const hex = '#' + [r, g, b].map(x => {
        const hex = x.toString(16);
        return hex.length === 1 ? '0' + hex : hex;
    }).join('');
    
    const colorBox = document.getElementById('colorBox');
    const colorCode = document.getElementById('colorCode');
    
    if (colorBox && colorCode) {
        colorBox.style.backgroundColor = hex;
        colorCode.textContent = hex.toUpperCase();
        
        // Add animation
        colorBox.style.transform = 'scale(0.9)';
        setTimeout(() => {
            colorBox.style.transform = 'scale(1)';
        }, 100);
    }
}

function copyColor() {
    const colorCode = document.getElementById('colorCode').textContent;
    navigator.clipboard.writeText(colorCode).then(() => {
        // Show success feedback
        const button = event.target.closest('button');
        const originalText = button.innerHTML;
        button.innerHTML = '<i class="fas fa-check"></i> Copied!';
        button.style.backgroundColor = 'var(--success-color)';
        
        setTimeout(() => {
            button.innerHTML = originalText;
            button.style.backgroundColor = '';
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy color: ', err);
    });
}

// Todo list functionality
function addTodo() {
    const todoInput = document.getElementById('todoInput');
    const todoList = document.getElementById('todoList');
    const text = todoInput.value.trim();
    
    if (!text) {
        return;
    }
    
    const li = document.createElement('li');
    li.innerHTML = `
        <span>${text}</span>
        <button onclick="removeTodo(this)" class="btn btn-danger btn-small">
            <i class="fas fa-trash"></i>
        </button>
    `;
    
    // Add animation
    li.style.opacity = '0';
    li.style.transform = 'translateX(-20px)';
    todoList.appendChild(li);
    
    // Trigger animation
    setTimeout(() => {
        li.style.transition = 'all 0.3s ease';
        li.style.opacity = '1';
        li.style.transform = 'translateX(0)';
    }, 10);
    
    todoInput.value = '';
}

function removeTodo(button) {
    const li = button.closest('li');
    li.style.transition = 'all 0.3s ease';
    li.style.opacity = '0';
    li.style.transform = 'translateX(20px)';
    
    setTimeout(() => {
        li.remove();
    }, 300);
}

// World clock functionality
function updateClocks() {
    const now = new Date();
    
    // Local time
    const localTimeElement = document.querySelector('#localTime .time-display');
    if (localTimeElement) {
        localTimeElement.textContent = now.toLocaleTimeString();
    }
    
    // UTC time
    const utcTimeElement = document.querySelector('#utcTime .time-display');
    if (utcTimeElement) {
        utcTimeElement.textContent = now.toUTCString().split(' ')[4];
    }
    
    // Tokyo time
    const tokyoTimeElement = document.querySelector('#tokyoTime .time-display');
    if (tokyoTimeElement) {
        const tokyoTime = new Date(now.toLocaleString("en-US", {timeZone: "Asia/Tokyo"}));
        tokyoTimeElement.textContent = tokyoTime.toTimeString().split(' ')[0];
    }
}

// Allow Enter key for todo input
document.addEventListener('DOMContentLoaded', function() {
    const todoInput = document.getElementById('todoInput');
    if (todoInput) {
        todoInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                addTodo();
            }
        });
    }
    
    // Calculator enter key support
    const calcInputs = document.querySelectorAll('#num1, #num2');
    calcInputs.forEach(input => {
        input.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                calculate();
            }
        });
    });
});

// Intersection Observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe feature cards and demo cards
document.addEventListener('DOMContentLoaded', function() {
    const cards = document.querySelectorAll('.feature-card, .demo-card');
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = `all 0.6s ease ${index * 0.1}s`;
        observer.observe(card);
    });
});

// Add some interactive effects
document.addEventListener('DOMContentLoaded', function() {
    // Add ripple effect to buttons
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            const ripple = document.createElement('div');
            const rect = button.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                left: ${x}px;
                top: ${y}px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                transform: scale(0);
                animation: ripple 0.6s ease-out;
                pointer-events: none;
            `;
            
            button.style.position = 'relative';
            button.style.overflow = 'hidden';
            button.appendChild(ripple);
            
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });
});

// Add CSS for ripple animation
const style = document.createElement('style');
style.textContent = `
@keyframes ripple {
    to {
        transform: scale(2);
        opacity: 0;
    }
}
`;
document.head.appendChild(style);
