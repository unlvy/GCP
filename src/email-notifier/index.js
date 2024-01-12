exports.email_notifier = (event, context) => {
    const nodemailer = require('nodemailer');
    const smtp = require('nodemailer-smtp-transport');

    const transporter = nodemailer.createTransport(
        smtp({
          host: 'in.mailjet.com',
          port: 2525,
          auth: {
            user: process.env.MAILJET_USERNAME,
            pass: process.env.MAILJET_PASSWORD,
          },
        })
      );
    
    transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: process.env.EMAIL_TO,
        subject: '',
        text: event.data,
    }).then().catch(console.error);
};