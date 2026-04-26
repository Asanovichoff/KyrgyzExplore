package com.kyrgyzexplore.message;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {

    Page<Message> findByBookingIdOrderByCreatedAtAsc(UUID bookingId, Pageable pageable);

    /**
     * Marks all unread messages in a conversation as read, excluding messages
     * sent by the reader themselves (you can't "read" your own messages).
     */
    @Modifying
    @Query("UPDATE Message m SET m.isRead = true " +
           "WHERE m.bookingId = :bookingId AND m.senderId != :readerId AND m.isRead = false")
    int markConversationAsRead(@Param("bookingId") UUID bookingId, @Param("readerId") UUID readerId);
}
