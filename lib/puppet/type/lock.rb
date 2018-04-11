Puppet::Type.newtype(:lock) do
  @doc = "Create a shared lock"

  ensurable

  newparam(:name) do
    desc "The name of the lock."
  end
end