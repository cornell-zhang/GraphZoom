function email_config()
%EMAIL_CONFIG Set up email.
%   EMAIL_CONFIG() prepares the environment for sending emails.
%
%   See also: CONFIG.
%
%   If no FILENAME is specified, 'config_ENV.txt' is used by default, where
%   ENV is the value of the environment variable 'MATLAB_PROFILE'.
%
%   See also: http://www.mathworks.com/support/solutions/en/data/1-3PRRDV/

% Define these variables appropriately:
mail = 'lamgautomailer@gmail.com'; %Your GMail email address
password = 'lamg1234'; %Your GMail password

% Then this code will set up the preferences properly:
setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');
end
