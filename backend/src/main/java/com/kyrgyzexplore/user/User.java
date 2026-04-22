package com.kyrgyzexplore.user;

import com.kyrgyzexplore.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

/**
 * WHY does User implement UserDetails?
 * Spring Security's authentication system requires a UserDetails object.
 * Implementing it directly on the entity means we don't need a separate
 * wrapper class — one less file to maintain. The trade-off is that the
 * entity is coupled to Spring Security, which is acceptable for a monolith.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User extends BaseEntity implements UserDetails {

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserRole role;

    @Column(nullable = false, length = 100)
    private String firstName;

    @Column(nullable = false, length = 100)
    private String lastName;

    @Column(length = 30)
    private String phone;

    private String profileImageUrl;

    private String stripeAccountId;

    @Column(nullable = false)
    @Builder.Default
    private boolean isActive = true;

    // ── UserDetails interface ────────────────────────────────────────────────

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // ROLE_ prefix is a Spring Security convention for role-based access control
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override
    public String getPassword() {
        return passwordHash;
    }

    @Override
    public String getUsername() {
        // Spring Security identifies users by username — we use email
        return email;
    }

    @Override
    public boolean isAccountNonLocked() {
        return isActive;
    }

    @Override
    public boolean isEnabled() {
        return isActive;
    }
}
