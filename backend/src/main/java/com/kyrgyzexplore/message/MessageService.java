package com.kyrgyzexplore.message;

import com.kyrgyzexplore.booking.Booking;
import com.kyrgyzexplore.booking.BookingRepository;
import com.kyrgyzexplore.common.exception.AppException;
import com.kyrgyzexplore.listing.Listing;
import com.kyrgyzexplore.listing.ListingRepository;
import com.kyrgyzexplore.message.dto.MessageResponse;
import com.kyrgyzexplore.notification.NotificationService;
import com.kyrgyzexplore.notification.NotificationType;
import com.kyrgyzexplore.user.User;
import com.kyrgyzexplore.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class MessageService {

    private final MessageRepository messageRepository;
    private final BookingRepository bookingRepository;
    private final ListingRepository listingRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Saves a message and broadcasts it on the booking's WebSocket topic.
     * Also sends a NEW_MESSAGE notification to the other party.
     *
     * WHY broadcast after saving (not before)?
     * If the DB save fails (e.g. constraint violation), we don't want to have
     * already sent a WebSocket message that refers to a non-existent record.
     * Save first, then push — so the recipient can always fetch the message
     * from the REST API if the WebSocket delivery fails.
     */
    @Transactional
    public MessageResponse send(UUID bookingId, UUID senderId, String content) {
        Booking booking = loadBookingOrThrow(bookingId);
        Listing listing = loadListingOrThrow(booking.getListingId());
        verifyParticipant(booking, listing, senderId);

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Sender not found"));

        Message message = Message.builder()
                .bookingId(bookingId)
                .senderId(senderId)
                .content(content)
                .build();

        Message saved = messageRepository.save(message);
        MessageResponse response = toResponse(saved, sender);

        // Push to /topic/booking/{bookingId} — both traveler and host receive it
        messagingTemplate.convertAndSend("/topic/booking/" + bookingId, response);

        // Notify the other party
        UUID recipientId = senderId.equals(booking.getTravelerId())
                ? listing.getHostId()
                : booking.getTravelerId();

        notificationService.notify(
                recipientId,
                NotificationType.NEW_MESSAGE,
                "New message from " + sender.getFirstName(),
                content.length() > 100 ? content.substring(0, 97) + "..." : content,
                bookingId
        );

        return response;
    }

    @Transactional(readOnly = true)
    public Page<MessageResponse> getHistory(UUID bookingId, UUID callerId, Pageable pageable) {
        Booking booking = loadBookingOrThrow(bookingId);
        Listing listing = loadListingOrThrow(booking.getListingId());
        verifyParticipant(booking, listing, callerId);

        return messageRepository.findByBookingIdOrderByCreatedAtAsc(bookingId, pageable)
                .map(m -> {
                    User sender = userRepository.findById(m.getSenderId())
                            .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Sender not found"));
                    return toResponse(m, sender);
                });
    }

    @Transactional
    public int markConversationAsRead(UUID bookingId, UUID callerId) {
        Booking booking = loadBookingOrThrow(bookingId);
        Listing listing = loadListingOrThrow(booking.getListingId());
        verifyParticipant(booking, listing, callerId);

        return messageRepository.markConversationAsRead(bookingId, callerId);
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private Booking loadBookingOrThrow(UUID bookingId) {
        return bookingRepository.findById(bookingId)
                .orElseThrow(() -> AppException.notFound("BOOKING_NOT_FOUND", "Booking not found"));
    }

    private Listing loadListingOrThrow(UUID listingId) {
        return listingRepository.findByIdAndDeletedAtIsNull(listingId)
                .orElseThrow(() -> AppException.notFound("LISTING_NOT_FOUND", "Listing not found"));
    }

    private void verifyParticipant(Booking booking, Listing listing, UUID callerId) {
        boolean isTraveler = booking.getTravelerId().equals(callerId);
        boolean isHost = listing.getHostId().equals(callerId);
        if (!isTraveler && !isHost) {
            throw AppException.forbidden("MESSAGE_FORBIDDEN",
                    "Only the traveler or host of this booking can send messages");
        }
    }

    private MessageResponse toResponse(Message m, User sender) {
        return MessageResponse.builder()
                .id(m.getId())
                .bookingId(m.getBookingId())
                .senderId(m.getSenderId())
                .senderName(sender.getFirstName() + " " + sender.getLastName())
                .content(m.getContent())
                .isRead(m.isRead())
                .createdAt(m.getCreatedAt())
                .build();
    }
}
