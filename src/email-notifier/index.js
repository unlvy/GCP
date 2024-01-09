exports.email_notifier = (event, context) => {
    const nodemailer = require('nodemailer');
    const smtp = require('nodemailer-smtp-transport');

    const transporter = nodemailer.createTransport(
        smtp({
          host: 'in.mailjet.com',
          port: 2525,
          auth: {
            user: '',
            pass: '',
          },
        })
      );
    
    transporter.sendMail({
        from: '',
        to: '',
        subject: '',
        text: event.data,
    }).then().catch(console.error);
};