package org.example.olympic_ot_project.controller;

import lombok.RequiredArgsConstructor;
import org.example.olympic_ot_project.core.AccountStudentStatus;
import org.example.olympic_ot_project.enity.Role;
import org.example.olympic_ot_project.enity.Users;
import org.example.olympic_ot_project.repositoy.RoleRepository;
import org.example.olympic_ot_project.repositoy.UsersRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dev")
@RequiredArgsConstructor
public class DevController {

    private final UsersRepository usersRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/init-admin")
    public void initAdmin() {

        if (usersRepository.existsByUsername("admin")) {
            return;
        }

        Users u = new Users();
        u.setUsername("admin");
        u.setPassword(passwordEncoder.encode("123456"));
        u.setEmail("admin@gmail.com");
        u.setFullName("Admin System");

        Role role = roleRepository.findById(1)
                .orElseThrow(() -> new RuntimeException("Role not found"));

        u.setRole(role);
        u.setStatus(AccountStudentStatus.ACTIVE);

        usersRepository.save(u);
    }
}
