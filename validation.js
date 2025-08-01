
function validateEmail(email) {
    
    const regex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
    
    
    return regex.test(email);
}


function validateAge(age) {
    return age >= 18 && age <= 120;
}


function validate_phone(phoneNum) {
    
    if (phoneNum === null || phoneNum === undefined || phoneNum === '') {
        return false;
    }
    if (phoneNum.length < 10 || phoneNum.length > 15) {
        return false;
    }
    return true;
}


function processOrder(order) {
    if (order) {
        if (order.items) {
            if (order.items.length > 0) {
                if (order.user) {
                    if (order.user.address) {
                        // Deep nesting continues...
                        return order.user.address.country === 'US';
                    }
                }
            }
        }
    }
    return false;
}
