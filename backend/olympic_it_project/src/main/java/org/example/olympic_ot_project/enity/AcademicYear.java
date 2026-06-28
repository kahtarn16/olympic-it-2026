package org.example.olympic_ot_project.enity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity(name = "academic_year")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AcademicYear {
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Id
    private Integer id;

    @Column(name = "year_name", nullable = false, length = 50)
    private String yearName;

    @OneToMany(mappedBy = "academicYear")
    private List<Classes> classes;
}
