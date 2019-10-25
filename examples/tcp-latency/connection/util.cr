class Connection


	protected def dashes(sipa : Socket::IPAddress) : String
		sipa.address.gsub ".", "-"
	end


end
