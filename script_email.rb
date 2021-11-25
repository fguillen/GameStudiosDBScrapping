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
  FROM_EMAIL = "fernando@playcocola.com"
  FROM_NAME = "Fernando from Playcocola"

  def run
    # content =

    # subject = "3 lines test 02"
    # from = "hello@playcocola.com"
    # to = "fguillen.mail@gmail.com"

    # # puts content
    # status = send_email(from, to, subject, content)

    # puts status

    contacts = get_contacts(CONTACTS_FILE_PATH)

    contacts.each do |contact|
      send_email_to_contact(contact)
    end
  end

  def send_email_to_contact(contact)
    puts contact
    content = CONTENT_TEMPLATE
    content = content.gsub("[NAME]", contact["name_1"])
    to = "fguillen.mail@gmail.com" # contact["email"]
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

    send_grid_api = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    response = send_grid_api.client.mail._("send").post(request_body: mail.to_json)
    response.status_code
  end
end

SendEmails.new.run
