use bcrypt;

fn main() {
    let password = "admin123";
    let hash = bcrypt::hash(password, bcrypt::DEFAULT_COST).unwrap();
    println!("Password: {}", password);
    println!("Hash: {}", hash);
    
    // Verify it works
    let valid = bcrypt::verify(password, &hash).unwrap();
    println!("Verification: {}", valid);
}