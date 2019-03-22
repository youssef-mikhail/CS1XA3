import requests
#from lxml import html
import smtplib
from time import sleep
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

session_requests = requests.session()

#f = open("comparison.txt", "r")
#reference = f.read()
#f.close()

def send_email(msg, htmlText=""):
    if htmlText != "":
        part1 = MIMEText(msg, "plain")
        part2 = MIMEText(htmlText, "html")
    
    message = MIMEMultipart("alternative")
    message["Subject"] = msg
    message["From"] = "ruler224@gmail.com"
    message["To"] = "mikhaily@mcmaster.ca"

    message.attach(part1)
    message.attach(part2)

    print("Establishing eonnection with smtp.gmail.com")
    email_server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    print("Logging in...")
    email_server.login("ruler224@gmail.com", "*password*") #I generated an app specific password for the login. I don't advice leaving your password here in plain text though
    print("Sending email...")
    email_server.sendmail("ruler224@gmail.com", "mikhaily@mcmaster.ca", message.as_string())
    print("sent email!")


#login without credentials using a preixisting token (lol) 
#you can get this URL by using Google Chrome's network monitor while logging in (I changed it so the URL below will no longer work)
url = "https://www.childsmath.ca/childsa/forms/main_login.php?token=998b7469c62bfe0aa3adcdcfc02b963111f8ff97805dc2696d4334f23e7ba8fd01c5703899e9353546c8f2f9e7b6eae16979a0b79abc19a5cacfae886d03da2533dd74e6a46e53d3f79758bfe21775e4329f92e578103947f545fee190702fab&authz=998b7469d62bfe0adbd0284cfda71e3cbac407522af71a5d13786248a57e82b00f726652022b5c39a3a3c44e02f4ae8dc23b7f83558e6a41e90f11334eea7bf9ea3d40d852406b5a53b7ed658c251b465dfbe1141ac8ad9852fe239ef64080e2e242500d30c16d88f4f59783dcf18ba528d90f6afbe74168a1ca8b3676106c995ab554f0f617ba0e66d2d95c3e60cdeca5d6babbc1516f9ba3b22655695878a0b243dc400857e1f36ee6923a4d7ce22be60a22e802869486fe2f0f185f13871843adcd843abc57d5cf064ae6458e899294529531095703ba29fa949ebe6af2b2d47c6c51e34b7ccfd58aa7d604b18e89c906060c0a96429848a5825c0e1aa385941117b8b3eab436c04fa4fae1a8dc471c8fffc5497a7d65e0d0fdf9a785f117e3e9704bcfb06b315cce4481f3f92e7d9c0467d86d48fb507a2cfce89e285729f93a411919001d752b59a961abfcbf373e4ec5089d96af7ae9832a5fab080ba562355ad9fca662a27de2e810a3bb28f1bc0840bf7299796c7c81fb63eb2765bd9ae6634b29559c50e2145f9656a724692691f413da4659244969847a2f55c8de88cc18595c7f0295b4d00a44cd9a5edb093300dc03d6e676077f29260c902feeca54abb04d5a6349453b9fe905ba25cffd988791e98ebc6eae7067ea797b88bbe2abddc6ba85761dfb6d40cc1df7e24529138d1203799dd461e49c3011ba6b67c23bd09a118b3cc89692c919f66b2416ba944a89c0d60e1ebbad381c5e0bd3c820078193e579f3b239ac6beba014e612292ab400b1813e3a8a5ff79dae4a21c166feeb13e9b1b5606c19d4c3c20876b72acc5d90640c2421eb4a5e95ba8c16a377f202fdc303833e4aa3b9f76dfe6de51cb9279ffe666887ba6c25ae6bf39b75dc05549538be0e551e5e41ff25ccecaf6a2f6c91e6425473288d55f4ab33f65aa4e3a7289a912d78f0f399e96cb98e5169ef342390a065d0c38e67aaaff34996fa2c27326d3b7d4d8a98f84d2498ad2ffa528da9662e5994"
result = session_requests.get(
    url,
    headers = dict(referer = "https://cap.mcmaster.ca/mcauth/login.jsp?app_id=1492&app_name=CHILDSMATH.CA&submit=MacID+Login")
)


#get announcements page on childsmath website
url = "https://www.childsmath.ca/childsa/forms/1zStuff/announce.php"
result = session_requests.get(
    url, headers = dict(referer = url) )

privannouncements = result.text

#get public announcements on public 1ZB3 page
url = "https://ms.mcmaster.ca/~mcleac3/math1AA3/Utils/Ups.html"
result = session_requests.get(
    url, headers = dict(referer = url) )

publicannouncements = result.text

#get my grades
url = "https://www.childsmath.ca/childsa/forms/1zStuff/marks.php"
result = session_requests.get(
    url, headers = dict(referer = url ) )


gradespage = result.text

#this loop checks for changes to the above webpages from when they were fetched at the beginning of the script
while True:
    try:
        url = "https://www.childsmath.ca/childsa/forms/1zStuff/marks.php"
        result = session_requests.get(
            url, headers = dict(referer = url) )

        if result.text != gradespage:
            print("Grades change found! Sending email...")
            send_email("Marks are out on childsmath!", result.text)
            quit(0)

        url = "https://ms.mcmaster.ca/~mcleac3/math1AA3/Utils/Ups.html"
        result = session_requests.get(
            url, headers = dict(referer = url) )

        if result.text != publicannouncements:
            print("Announcements change found! Sending email...")
            send_email("New announcement on public 1ZB3 page!", result.text)
            publicannouncements = result.text
        
        
        url = "https://www.childsmath.ca/childsa/forms/1zStuff/announce.php"
        result = session_requests.get(
            url, headers = dict(referer = url) )

        if result.text != privannouncements:
            print("Announcements change found on childsmath! Sending email..,")
            send_email("There is a new announcement on childsmath!", result.text)
            privannouncements = result.text
        
        print("no grades change found")

        #wait for 30 seconds before checking again
        sleep(30)
    except KeyboardInterrupt:
        quit(0)
    except Exception as e:
        send_email("An error occured in the script. Details are: " + str(e))
        quit(0)




