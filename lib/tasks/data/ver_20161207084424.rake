namespace :data do
  desc "data modifications for 20161207084424_add_data_model"
  task ver_20161207084424: :environment do
    def data_migration(user_id, analyses_con, old_analyses)

      old_analyses.each do |ana|
        ana_con = Container.create! :parent => analyses_con
        ana_con.container_type = ana["type"]
        ana_con.name = ana["name"]
        ana_con.description = ana["description"]

        ana_con.extended_metadata['report'] = ana["report"]
        ana_con.extended_metadata["kind"] = ana["kind"]
        ana_con.extended_metadata["status"] = ana["status"]
        ana_con.extended_metadata["report"] = ana["report"]
        ana_con.extended_metadata["content"] = ana["content"].to_json.to_s

        ana_con.save!

        ana["datasets"].each do |dataset|
          d_con = Container.create! :parent => ana_con
          d_con.container_type = dataset["type"]
          d_con.name = dataset["name"]
          d_con.description = dataset["description"]
          d_con.extended_metadata["instrument"] = dataset["instrument"]

          d_con.save!

          dataset["attachments"].each do |attach|

            if attach['name']
              split = attach["name"].split('.')
              if split.length == 2
                file_ext = split[1]
                file_id = "uploads/attachments/" + attach["filename"] + "." + file_ext

                if File.exists?(file_id)
                  sha256 = Digest::SHA256.file(file_id).hexdigest

                  storage = Storage.new
                  uuid = SecureRandom.uuid
                  storage.create(uuid, attach["name"], IO.binread(file_id), sha256, user_id, user_id)
                  storage.update(uuid, d_con.id)
                end
              end
            end
          end
        end
      end
    end

    Sample.find_each do |s|
      if s.container == nil
        s.container = ContainerHelper.create_root_container
        s.save!

        ana_con = s.container.children.detect { |con| con.container_type == "analyses" }

        data_migration(s.created_by, ana_con, s.analyses)
      end
    end

    Reaction.find_each do |r|
      if r.container == nil
        r.container = ContainerHelper.create_root_container
        r.save!
      end
    end

    Wellplate.find_each do |w|
      if w.container == nil
        w.container = ContainerHelper.create_root_container
        w.save!
      end
    end

    Screen.find_each do |s|
      if s.container == nil
        s.container = ContainerHelper.create_root_container
        s.save!
      end
    end
  end
end
