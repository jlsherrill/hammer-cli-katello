require_relative '../test_helper'
require 'hammer_cli_foreman/hostgroup'

module HammerCLIForeman
  describe Hostgroup do
    # These tests are only for the extensions Katello adds to the hostgroup command
    # See hammer-cli-foreman for the core hostgroup tests
    describe CreateCommand do
      it 'allows content source id' do
        api_expects(:hostgroups, :create) do |p|
          p['hostgroup']['name'] == 'hg1' && p['hostgroup']['content_source_id'] == 1
        end
        run_cmd(%w(hostgroup create --name hg1 --content-source-id 1))
      end

      it 'allows content source name' do
        content_source_name = "life_of_cs"
        content_source_id = 111
        hg_name = "mercury"

        api_expects(:smart_proxies, :index).
          with_params(:search => "name = \"#{content_source_name}\"").
          returns(index_response([{'id' => content_source_id}]))

        api_expects(:hostgroups, :create).
          with_params('hostgroup' => {'name' => hg_name,
                                      'content_source_id' => content_source_id
                                     })

        cmd = "hostgroup create --name #{hg_name} --content-source #{content_source_name}"
        run_cmd(cmd.split)
      end

      it 'allows content view id' do
        api_expects(:hostgroups, :create) do |p|
          p['hostgroup']['name'] == 'hg1' && p['hostgroup']['content_view_id'] == 1
        end
        run_cmd(%w(hostgroup create --name hg1 --content-view-id 1))
      end

      it 'allows content view name' do
        ex = api_expects(:content_views, :index) do |p|
          p[:search] = "name = \"cv1\"" && p['organization_id'] == '1'
        end
        ex.returns(index_response([{'id' => 1}]))
        api_expects(:hostgroups, :create) do |p|
          p['hostgroup']['content_view_id'] == 1 && p['hostgroup']['name'] == 'hg1'
        end
        run_cmd(%w(hostgroup create --name hg1 --content-view cv1 --query-organization-id 1))
      end

      it 'requires organization options to resolve content view name' do
        api_expects_no_call
        result = run_cmd(%w(hostgroup create --name hg1 --content-view cv1))
        assert_match(/--query-organization/, result.err)
      end

      it 'allows lifecycle environment id' do
        api_expects(:hostgroups, :create) do |p|
          p['hostgroup']['name'] == 'hg1' && p['hostgroup']['lifecycle_environment_id'] == 1 &&
            p['hostgroup']['organization_ids'] == %w(1 2)
        end
        run_cmd(%w(hostgroup create --name hg1 --lifecycle-environment-id 1 --organization-ids 1,2))
      end

      it 'allows lifecycle environment name' do
        ex = api_expects(:lifecycle_environments, :index) do |p|
          p['name'] == 'le1' && p['organization_id'] == '1'
        end
        ex.returns(index_response([{'id' => 1}]))
        api_expects(:hostgroups, :create) do |p|
          p['hostgroup']['name'] == 'hg1' && p['hostgroup']['lifecycle_environment_id'] == 1
        end
        run_cmd(%w(hostgroup create --name hg1 --lifecycle-environment le1
                   --query-organization-id 1 --organization-ids 1,2))
      end

      it 'requires organization options to resolve lifecycle environment name' do
        api_expects_no_call
        result = run_cmd(%w(hostgroup create --name hg1 --lifecycle-environment le1))
        assert_match(/--query-organization/, result.err)
      end

      it 'allows kickstart repository name' do
        env_id = 100
        cv_id = 200
        repo_name = "life_of_kickstart"
        repo_id = 111
        hg_name = "mercury"

        api_expects(:repositories, :index).
          with_params('name' => repo_name,
                      'environment_id' => env_id,
                      'content_view_id' => cv_id).
          returns(index_response([{'id' => repo_id}]))

        expected_params = {'hostgroup' => {
          'name' => hg_name,
          'lifecycle_environment_id' => env_id,
          'content_view_id' => cv_id,
          'kickstart_repository_id' => repo_id
        }
                          }
        api_expects(:hostgroups, :create).with_params(expected_params)

        cmd = "hostgroup create --name #{hg_name} --lifecycle-environment-id #{env_id}"\
              " --content-view-id #{cv_id} --kickstart-repository #{repo_name}"
        run_cmd(cmd.split)
      end
    end
  end
end
