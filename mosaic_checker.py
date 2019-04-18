import requests
from lxml import html
import smtplib
from time import sleep
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

session_requests = requests.session()

payload = {
    "userid" : "MacID",  #insert MacID here
    "pwd" : "password", #insert MacID password here
    "ptlangcd" : "ENG",
    "ptinstalledlang" : "ENG",
    "ptlangsel" : "ENG",
    "ptmode" : "f",
    "timezoneOffset" : "240"
}


def send_email(subject, msg, htmlText=""):
    part1 = MIMEText(msg, "plain")
    part2 = MIMEText(htmlText, "html")

    if htmlText == "":
        part2 = MIMEText(msg, "plain")
    
    message = MIMEMultipart("alternative")
    message["Subject"] = subject
    message["From"] = "ruler224@gmail.com" #source email
    message["To"] = "mikhaily@mcmaster.ca" #destination email

    message.attach(part1)
    message.attach(part2)

#    print("Establishing eonnection with smtp.gmail.com")
    email_server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
 #   print("Logging in...")
    email_server.login("ruler224@gmail.com", "*password*") #I generated an app specific password for the login. I don't advice leaving your password here in plain text though
  #  print("Sending email...")
    email_server.sendmail("ruler224@gmail.com", "mikhaily@mcmaster.ca", message.as_string()) #replace these your source and destination emails
   # print("sent email!")



#The URL for the grades iframe on Mosaic
url = "https://csprd.mcmaster.ca/psc/prcsprd/EMPLOYEE/SA/c/SA_LEARNER_SERVICES.SSR_SSENRL_GRADE.GBL?Page=SSR_SSENRL_GRADE&Action=A&TargetFrameName=None&&&"
result = session_requests.get(url)

#log in with the parameters specified at the top of the file
result = session_requests.post(
    url,
    data = payload,
    headers = dict(referer=url)
)




#Scrape course name cells from the table
tree = html.fromstring(result.content)
course_names = tree.xpath("//a[@class='PSHYPERLINK']/text()")[:-1]
print("Course names: ")
print(course_names)

#scrape grade cells from the table 
oldMarks = tree.xpath("//span[@class='PABOLDTEXT']/text()")[1:]
print("Initial course marks")
print(oldMarks)




#this loop checks for changes to the above webpage from when they were fetched at the beginning of the script
while True:
    try:
        result = session_requests.get(
            url, headers = dict(referer = url) )
        
        tree = html.fromstring(result.content)
        marks = tree.xpath("//span[@class='PABOLDTEXT']/text()")[1:]
        #compare marks that were just fetched to the marks fetched before the loop
        if marks != oldMarks:
            #Grab the new mark, which is the entry in the list that differs from the old mark list
            differentMarks = [index for index, i in enumerate(marks) if i != oldMarks[index]]
#            print("Grades change found! Sending email...")
 #           print("For course ", course_names[differentMarks[0]])
            #send email
            send_email("Final marks released", "Your mark for " + course_names[differentMarks[0]] + " is out. Your mark is: " + marks[differentMarks[0]])
            oldMarks = marks

        
        
  #      print("no grades change found")

        #wait for 30 seconds before checking again
        sleep(30)
    except KeyboardInterrupt:
        quit(0)
    except Exception as e:
        send_email("Script failed", "An error occured in the script. Details are: " + str(e))
   #     print("Error: ", str(e))
        quit(0)




