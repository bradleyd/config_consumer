# Generated amqp daemon
DaemonKit::Application.running! do |config|
  config.trap( 'INT' ) do
    # do something clever
  end
  config.trap( 'TERM', Proc.new { puts 'Going down' } )
end

@account_uuid = #gets set during container creation

# Run an event-loop for processing
DaemonKit::AMQP.run do |connection|
  connection.on_tcp_connection_loss do |client, settings|
    DaemonKit.logger.debug("AMQP connection status changed: #{client.status}")
    client.reconnect(false, 1)
  end

  channel      = AMQP::Channel.new(connection,AMQP::Channel.next_channel_id, :auto_recovery => true)
  channel.prefetch(1)
  exchange     = channel.direct("amq.direct")
  queue    = channel.queue("handlers", 
                           :durable => true, 
                           :auto_delete => false, 
                           :arguments => {'x-ha-policy' => 'all'}).bind(exchange, :key => @account_uuid) 

  # connection error
  connection.on_error do |conn, connection_close|
    puts "[connection.close] Reply code = #{connection_close.reply_code}, reply text = #{connection_close.reply_text}"
    if connection_close.reply_code == 320
      puts "[connection.close] Setting up a periodic reconnection timer..."
      #every 30 seconds
      conn.periodically_reconnect(30)
    end
  end

  # check if channel is auto recovering 
  if channel.auto_recovering?
    puts "Channel #{channel.id} IS auto-recovering"
  end

  # check channel error
  channel.on_error do |ch, channel_close|
    puts channel_close.reply_text
    connection.close { EventMachine.stop }
  end

  # tcp error
  connection.on_tcp_connection_loss do |conn, settings|
    DaemonKit.logger.error "[network failure] Trying to reconnect..."
    conn.reconnect(false, 2)
  end

  # alert connection has recovered
  connection.on_recovery do |conn, settings|
    DaemonKit.logger.info "[recovery] Connection has recovered"
  end
  
  # check queue basic info
  queue.status { |number_of_messages, number_of_active_consumers|
    DaemonKit.logger.info "Listening on Queue: #{AGE_BUCKET["queue"]}"
    @messages = number_of_messages

  }

  # subscribe to the queue and do work
  queue.subscribe(:ack => true) do |meta, msg|
    message = JSON.parse(msg)
    # payload should have a type, name, payload
    writer = ConfigConsumer::Writer.new(:handler, message["name"], message["payload"])
    if writer.save
      #HUP sensu?
      #meta.ack
    else
      #meta.reject
    end
    DaemonKit.logger.debug "Received message: #{msg.inspect}"

  end
end
