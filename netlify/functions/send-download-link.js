/**
 * JAB Systems - Download Link Email Function
 *
 * This Netlify Function sends download links via email when users
 * submit the download request form.
 *
 * Environment Variables Required:
 * - GMAIL_USER: Your Google Workspace email (e.g., info@jabsystems.io)
 * - GMAIL_APP_PASSWORD: 16-character App Password from Google
 *
 * Setup Instructions:
 * 1. Enable 2-Step Verification in Google Account
 * 2. Go to Google Account > Security > App Passwords
 * 3. Generate password for "Mail" on "Other (Netlify)"
 * 4. Add environment variables in Netlify Dashboard
 * 5. Configure form notification webhook in Netlify Forms settings
 */

const nodemailer = require('nodemailer');

// Email template for download link
const getEmailHTML = (name, downloadUrl) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #0b0f14; font-family: system-ui, -apple-system, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #0b0f14; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width: 600px;">
          <!-- Header -->
          <tr>
            <td style="padding-bottom: 30px; text-align: center;">
              <h1 style="color: #3aa0ff; margin: 0; font-size: 24px; font-weight: 600;">
                JAB Systems
              </h1>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td style="background-color: #111822; border-radius: 12px; padding: 40px;">
              <h2 style="color: #f5f7fa; margin: 0 0 20px; font-size: 22px;">
                Your Download is Ready
              </h2>

              <p style="color: #9aa7b8; margin: 0 0 20px; font-size: 16px; line-height: 1.6;">
                Hi ${name},
              </p>

              <p style="color: #9aa7b8; margin: 0 0 30px; font-size: 16px; line-height: 1.6;">
                Thank you for your interest in JAB Drive Hygiene Check. Click the button below to download the tool:
              </p>

              <!-- Download Button -->
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding: 20px 0;">
                    <a href="${downloadUrl}"
                       style="display: inline-block; background-color: #3aa0ff; color: #ffffff;
                              padding: 14px 32px; border-radius: 8px; text-decoration: none;
                              font-weight: 600; font-size: 16px;">
                      Download JAB Drive Hygiene Check
                    </a>
                  </td>
                </tr>
              </table>

              <!-- What's Included -->
              <div style="background-color: rgba(58,160,255,0.1); border-radius: 8px; padding: 20px; margin-top: 20px;">
                <h3 style="color: #f5f7fa; margin: 0 0 12px; font-size: 16px;">What's Included:</h3>
                <ul style="color: #9aa7b8; margin: 0; padding-left: 20px; font-size: 14px; line-height: 1.8;">
                  <li>PowerShell script (JAB-DriveHygieneCheck.ps1)</li>
                  <li>Complete user documentation (README.md)</li>
                  <li>No installation required - just run it</li>
                </ul>
              </div>

              <!-- Quick Start -->
              <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid rgba(255,255,255,0.06);">
                <h3 style="color: #f5f7fa; margin: 0 0 12px; font-size: 16px;">Quick Start:</h3>
                <ol style="color: #9aa7b8; margin: 0; padding-left: 20px; font-size: 14px; line-height: 1.8;">
                  <li>Extract the downloaded files</li>
                  <li>Right-click JAB-DriveHygieneCheck.ps1</li>
                  <li>Select "Run with PowerShell"</li>
                  <li>Allow administrator access for full features</li>
                </ol>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding-top: 30px; text-align: center;">
              <p style="color: #9aa7b8; font-size: 14px; margin: 0 0 10px;">
                Questions? Reply to this email or visit
                <a href="https://jabsystems.io" style="color: #3aa0ff; text-decoration: none;">jabsystems.io</a>
              </p>
              <p style="color: #6b7a8a; font-size: 12px; margin: 0;">
                &copy; ${new Date().getFullYear()} JAB Systems. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// Plain text version
const getEmailText = (name, downloadUrl) => `
JAB Drive Hygiene Check - Download Ready

Hi ${name},

Thank you for your interest in JAB Drive Hygiene Check.

Download your copy here:
${downloadUrl}

Quick Start:
1. Extract the downloaded files
2. Right-click JAB-DriveHygieneCheck.ps1
3. Select "Run with PowerShell"
4. Allow administrator access for full features

Questions? Reply to this email or visit https://jabsystems.io

- JAB Systems
`;

exports.handler = async (event, context) => {
  // Only accept POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  try {
    // Parse the incoming webhook payload from Netlify Forms
    const payload = JSON.parse(event.body);

    // Netlify Forms webhook format
    const formData = payload.payload?.data || payload.data || payload;

    const { name, email, tool, message } = formData;

    // Only process drive-hygiene download requests
    if (tool !== 'JAB Drive Hygiene Check') {
      console.log(`Ignoring form submission for tool: ${tool}`);
      return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Ignored - different tool' })
      };
    }

    // Validate required fields
    if (!email || !name) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing required fields' })
      };
    }

    // Check environment variables
    const gmailUser = process.env.GMAIL_USER;
    const gmailPassword = process.env.GMAIL_APP_PASSWORD;

    if (!gmailUser || !gmailPassword) {
      console.error('Missing GMAIL_USER or GMAIL_APP_PASSWORD environment variables');
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Email configuration missing' })
      };
    }

    // Configure nodemailer with Google SMTP
    const transporter = nodemailer.createTransport({
      host: 'smtp.gmail.com',
      port: 587,
      secure: false, // Use TLS
      auth: {
        user: gmailUser,
        pass: gmailPassword
      }
    });

    // Download URL - update this to your actual download location
    // Options:
    // 1. Direct link to GitHub raw file
    // 2. Link to a releases page
    // 3. Link to a zip file on your CDN
    const downloadUrl = 'https://jabsystems.io/tools/drive-hygiene/JAB-DriveHygieneCheck.ps1';

    // Send the email
    const mailOptions = {
      from: {
        name: 'JAB Systems',
        address: gmailUser
      },
      to: email,
      subject: 'Your JAB Drive Hygiene Check Download',
      text: getEmailText(name, downloadUrl),
      html: getEmailHTML(name, downloadUrl)
    };

    await transporter.sendMail(mailOptions);

    console.log(`Download link sent to ${email} for ${name}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Email sent successfully',
        recipient: email
      })
    };

  } catch (error) {
    console.error('Error sending email:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: 'Failed to send email',
        details: error.message
      })
    };
  }
};
