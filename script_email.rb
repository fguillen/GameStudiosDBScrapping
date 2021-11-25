require "dotenv/load"
require "sendgrid-ruby"
require "csv"

CONTENT_TEMPLATE = <<~EOS
Hello [NAME],

My name is Fernando Guillen, I am also developing games myself but not, by far, as mature as yours :)

My speciality is web development and I am working on a new service to simplify how game developers collect video recordings from their play testers. Specifically, we are building simpler and better tools for the indie devs and for their play testers community.

Would be great if I could ask you a few questions to learn from your experience doing play testing and if you find it helpful receiving gameplay videos of your game. We can do it online or writing or how better suits you. I am not selling anything, just looking for your advice.

Please let me know if you can help me, it should be no more than 15 minutes.

Thanks in advance,

f.

--

Playcocola (https://land.playcocola.com)

EOS

SUBJECT_TEMPLATE = "Asking for advice and experience doing playtesting"

class SendEmails
  CONTACTS_FILE_PATH = "#{__dir__}/results/results_short.csv"
  CONTACTS_CONTACTED_FILE_PATH = "#{__dir__}/results/contacted.txt" # I could manipulate the CONTACTS_FILE_PATH but it is automatically generated by another script and can cause conflicts
  FROM_EMAIL = "fernando@playcocola.com"
  FROM_NAME = "Fernando from Playcocola"

  def run
    contacts = get_contacts(CONTACTS_FILE_PATH)

    contacts_count = contacts.length
    contacts.each_with_index do |contact, index|
      puts("Sending email [#{index + 1}/#{contacts_count}] (#{contact["email"]})")
      if(!contacted?(contact["email"]))
        # send_email_to_contact(contact)
        # File.open(CONTACTS_CONTACTED_FILE_PATH, "a") { |f| f << "#{contact["email"]}\n" }
      end
    end

    puts "End script :)"
  end

  def send_email_to_contact(contact)
    content = CONTENT_TEMPLATE
    content = content.gsub("[NAME]", contact["name_1"])
    to = contact["email"]
    from_email = FROM_EMAIL
    from_name = FROM_NAME
    subject = SUBJECT_TEMPLATE

    send_email(from_email, from_name, to, subject, content)
  end

  def get_contacts(file_path)
    CSV.read(file_path, headers: true)
  end

  def send_email(from_email, from_name, to, subject, content)
    puts("send_email(#{from_email}, #{from_name}, #{to}, #{subject})")
    from = SendGrid::Email.new(email: from_email, name: from_name)
    to = SendGrid::Email.new(email: to)
    content = SendGrid::Content.new(type: "text/plain", value: content)
    mail = SendGrid::Mail.new(from, subject, to, content)

    response = send_grid_api_client.mail._("send").post(request_body: mail.to_json)
    response.status_code
  end

  def send_grid_api_client
    @send_grid_client ||= SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"]).client
  end

  def contacted?(email)
    !File.foreach(CONTACTS_CONTACTED_FILE_PATH).grep(/#{email}/).empty? # I could some caching here but then I have to keep the cache updated in case there are duplicated emails in the contacts
  end
end

SendEmails.new.run
