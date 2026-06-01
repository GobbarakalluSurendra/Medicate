import os
import random
import datetime
import smtplib
from email.mime.text import MIMEText
from app.config import Config

# In-memory store for OTPs: { email: { 'otp': str, 'expiry': datetime } }
_otp_store = {}

def generate_otp(email):
    """
    Generates a 6-digit OTP code, saves it to memory with a 10-minute lifetime,
    attempts to email it using SMTP if configured, and prints to console as fallback.
    """
    otp = f"{random.randint(100000, 999999)}"
    expiry = datetime.datetime.now() + datetime.timedelta(minutes=10)
    
    _otp_store[email] = {
        'otp': otp,
        'expiry': expiry
    }
    
    # Check for SMTP configs
    smtp_server = os.environ.get('SMTP_SERVER')
    smtp_port = os.environ.get('SMTP_PORT')
    smtp_email = os.environ.get('SMTP_EMAIL')
    smtp_password = os.environ.get('SMTP_PASSWORD')

    email_sent = False
    
    if smtp_server and smtp_port and smtp_email and smtp_password:
        try:
            port = int(smtp_port)
            msg = MIMEText(
                f"Welcome to Aegis Health!\n\n"
                f"Your 6-digit verification code is: {otp}\n"
                f"This code will expire in 10 minutes.\n\n"
                f"If you did not request this, please ignore this email."
            )
            msg['Subject'] = "Aegis Health - OTP Verification Code"
            msg['From'] = smtp_email
            msg['To'] = email

            # Establish SMTP connection
            server = smtplib.SMTP(smtp_server, port, timeout=10)
            server.starttls()
            server.login(smtp_email, smtp_password)
            server.sendmail(smtp_email, [email], msg.as_string())
            server.quit()
            
            email_sent = True
            print(f"[OTP SERVICE] Email sent successfully to {email}")
        except Exception as smtp_error:
            print(f"[OTP SERVICE WARNING] SMTP transmission failed: {smtp_error}. Falling back to console output.")

    # Simulators printing to terminal console
    print("\n" + "=" * 50)
    print(f" [OTP SIMULATOR] Code for: {email}")
    print(f" >>> OTP CODE: {otp} <<<")
    print(f" Email Delivery status: {'SENT via SMTP' if email_sent else 'MOCKED / CONSOLE ONLY'}")
    print(f" Valid until: {expiry.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50 + "\n")
    
    return otp

def verify_otp(email, otp_to_verify):
    """
    Validates a given OTP against the stored dictionary.
    Returns True if valid and deletes it from cache. Returns False if expired or mismatched.
    """
    if email not in _otp_store:
        return False
        
    record = _otp_store[email]
    
    # Check expiry
    if datetime.datetime.now() > record['expiry']:
        del _otp_store[email]
        return False
        
    # Check match
    if record['otp'] == str(otp_to_verify).strip():
        del _otp_store[email] # Clear code once verified successfully
        return True
        
    return False
