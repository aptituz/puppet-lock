Puppet.features.rubygems?
require 'etcd' if Puppet.features.etcd?
require 'json'
require 'pry'

Puppet::Type.type(:lock).provide(:etcdctl) do
  commands :etcdctl => 'etcdctl'
  confine :feature => :etcd

  def create
    aquire_lock
  end

  def destroy
    Puppet.debug("releasing lock '#{resource[:name]}'")
    # FIXME: to be implemented
  end

  def exists?
    Puppet.debug("Trying to aquire lock for '#{resource[:name]}' via etcd")
    aquire_lock
  end

  private
  def client
    Etcd.client(port: 2379)
  end

  def aquire_lock
    path = '/puppet.com/lock/group'
    fqdn = "bla.fqdn"
    begin
      data = JSON.generate({ :holder => fqdn } )
      unless client.exists?('/puppet.com/lock/group')
        Puppet.debug("Lock in etcd does not exist yet, creating it with '#{fqdn}' as holder.")
        client.create(path, { :value => data } )
      else
        Puppet.debug("Lock already exists: trying to get a hold of it as holder '#{fqdn}'.")
        if client.compare_and_swap(path, { :value => data , :prevValue => data })
          Puppet.debug("Successfully aquired lock")
          true
        end
      end

      # FIXME for sure we need to handle more cases.
    rescue
      data = JSON.parse(client.get(path).value)
      raise Puppet::Error, "Unable to aquire lock: currently hold by '#{data["holder"]}'"
      Puppet.debug("Failed to aquire lock")
    end

  end
end