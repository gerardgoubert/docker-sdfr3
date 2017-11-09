# Use Base Ubuntu image
FROM ubuntu:16.04

# Author of this Dockerfile
MAINTAINER Singledigits, Inc. <singledigits.com>

# Update & upgrades
RUN apt-get update && apt-get upgrade -y

# Install dependencies
RUN apt-get install -y software-properties-common

# Add FR3 PPA
RUN add-apt-repository ppa:freeradius/stable-3.0 -y ; apt-get update ; apt-get install freeradius freeradius-postgresql freeradius-ldap -y
# Install FreeRADIUS and Google Authenticator
RUN apt-get install libpam-google-authenticator -y

# Add user to container with home directory
RUN useradd -m -d /home/singledigits -s /bin/bash singledigits

# Add password to singledigits account
RUN echo "singledigits:password" | chpasswd

# Edit /etc/pam.d/radiusd file
RUN sed -i 's/@include/#@include/g' /etc/pam.d/radiusd
RUN echo "auth requisite pam_google_authenticator.so forward_pass secret=/etc/freeradius/singledigits/.google_authenticator user=freerad" >> /etc/pam.d/radiusd
RUN echo "auth required pam_unix.so use_first_pass" >> /etc/pam.d/radiusd

# Edit /etc/freeradius/users file
RUN sed -i '1s/^/# Instruct FreeRADIUS to use PAM to authenticate users\n/' /etc/freeradius/users
RUN sed -i '2s/^/DEFAULT Auth-Type := PAM\n/' /etc/freeradius/users

# Copy existing /etc/freeradius/sites-enabled/default file to container
COPY default /etc/freeradius/sites-enabled/default

# Copy existing /etc/freeradius/clients.conf file to container
COPY clients.conf /etc/freeradius/clients.conf

# Copy existing .google_authenticator file to container
COPY .google_authenticator /home/singledigits

# Create a folder in /etc/freeradius equal to the user name
RUN mkdir /etc/freeradius/singledigits

# Copy .google_authenticator file to /etc/freeradius/networkjutsu
RUN cp /home/singledigits/.google_authenticator /etc/freeradius/singledigits

# Change owner to freerad
RUN chown freerad:freerad /etc/freeradius/singledigits && chown freerad:freerad /etc/freeradius/singledigits/.google_authenticator

# Expose the port
EXPOSE 1812/udp 1813/udp 18120/udp

# Run FreeRADIUS
#CMD freeradius3 -f
CMD ["/usr/sbin/freeradius", "-X"]
